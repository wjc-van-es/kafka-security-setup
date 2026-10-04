package nl.vea.kafka.security.util;

import javax.naming.InvalidNameException;
import javax.naming.ldap.LdapName;
import javax.naming.ldap.Rdn;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.Base64;


public class CertificateMetadataReader {

    private CertificateMetadataReader() {
    }

    public static X509Certificate parseCertificate(String base64Cert) throws CertificateException {

        byte[] certBytes = Base64.getDecoder().decode(base64Cert);
        CertificateFactory factory = CertificateFactory.getInstance("X.509");
        return (X509Certificate) factory.generateCertificate(new ByteArrayInputStream(certBytes));
    }

    public static String getSubject(String base64Cert) {

        if (base64Cert == null || base64Cert.isBlank()) {
            return null;
        }

        try {
            String subject = parseCertificate(base64Cert).getSubjectX500Principal().getName();
            return normalizeSubject(subject);
        } catch (Exception _) {
            return null;
        }
    }


    static String normalizeSubject(String subject) throws InvalidNameException {

        String country = "";
        String organisation = "";
        String serialNumber = "";
        String commonName = "";

        LdapName ldapName = new LdapName(subject);

        for (Rdn rdn : ldapName.getRdns()) {

            String type = rdn.getType().toUpperCase();
            String stringValue = getRdnValue(rdn);

            switch (type) {

                case "C":
                    country = stringValue;
                    break;

                case "O":
                    organisation = stringValue;
                    break;

                case "CN":
                    commonName = stringValue;
                    break;

                case "SERIALNUMBER","2.5.4.5":
                    serialNumber = stringValue;
                    break;

                default:
            }
        }

        return String.format(
                "C=%s, O=%s, serialNumber=%s, CN=%s",
                country,
                organisation,
                serialNumber,
                commonName);
    }

    private static String getRdnValue(Rdn rdn) {

        Object value = rdn.getValue();

        if (value instanceof byte[] bytes) {

            if (bytes.length > 2 && bytes[0] == 0x13) {
                return new String(
                        bytes,
                        2,
                        bytes.length - 2, StandardCharsets.US_ASCII);
            }

            return new String(bytes, StandardCharsets.US_ASCII);
        }

        return String.valueOf(value);
    }
}
