export PASSWORD=PIPPOBAUDO123

export WILDFLY_CONFIGURATION_DIR=wildfly_configuration
export KEYCLOAK_CONFIGURATION_DIR=keycloak_configuration
mkdir $WILDFLY_CONFIGURATION_DIR
mkdir $KEYCLOAK_CONFIGURATION_DIR


echo --------------
echo ROOT CA
echo --------------

export prefix=""
export CA_SUBJECT="$prefix/C=CZ/ST=BRNO/L=BRNO/O=Red Hat EAP QA/OU=Software/CN=qa.redhat.com/emailAddress=tborgato@redhat.com"
export CA_TRUSTSTORE=ca.truststore

echo "Generate the CA private key (ca.key):"
openssl genrsa -out ca.key 2048

echo "Create and self sign the root certificate (ca.crt):"
openssl req -new -x509 -key ca.key -subj "$CA_SUBJECT" -out ca.crt

echo "Import root CA certificate into truststore (ca.truststore):"
keytool -import -file ca.crt -keystore $CA_TRUSTSTORE -keypass $PASSWORD -storepass $PASSWORD -noprompt

echo "Copy CA truststore"
cp $CA_TRUSTSTORE $WILDFLY_CONFIGURATION_DIR
cp $CA_TRUSTSTORE $KEYCLOAK_CONFIGURATION_DIR


echo --------------
echo KEYCLOAK
echo --------------

export KEYCLOAK_SUBJECT="$prefix/C=CZ/ST=BRNO/L=BRNO/O=Red Hat EAP QA KEYCLOAK/OU=Software/CN=keycloak.qa.redhat.com/emailAddress=tborgato@redhat.com"

echo "Generate keycloak server key (keycloak.key):"
openssl genrsa -out keycloak.key 2048

echo "Generate keycloak certificate signing request (keycloak.csr):"
openssl req -new -key keycloak.key -subj "$KEYCLOAK_SUBJECT" -out keycloak.csr

echo "Sign keycloak CSR using CA key to generate server certificate (keycloak.crt):"
openssl x509 -req -days 3650 -in keycloak.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out keycloak.crt

# PKCS12: binary format for storing a certificate chain and private key in a single, encryptable file
echo "Store Keycloak cert & key and CA cert into pkcs12 format (keycloak.pkcs12):"
openssl pkcs12 -export -in keycloak.crt -inkey keycloak.key -out keycloak.pkcs12 -name myserverkeystore -CAfile ca.crt -passin pass:$PASSWORD  -passout pass:$PASSWORD

echo "Convert Keycloak pkcs12 file to Java keystore (keycloak.keystore):"
keytool -importkeystore -deststorepass $PASSWORD -destkeypass $PASSWORD -destkeystore keycloak.keystore -srckeystore keycloak.pkcs12 -srcstoretype PKCS12 -srcstorepass $PASSWORD

cp keycloak.keystore $KEYCLOAK_CONFIGURATION_DIR


echo --------------
echo WILDFLY
echo --------------

export WILDFLY_SUBJECT="$prefix/C=CZ/ST=BRNO/L=BRNO/O=Red Hat EAP QA WILDFLY/OU=Software/CN=wildfly.qa.redhat.com/emailAddress=tborgato@redhat.com"

echo "Generate wildfly server key (wildfly.key):"
openssl genrsa -out wildfly.key 2048

echo "Generate wildfly certificate signing request (wildfly.csr):"
openssl req -new -key wildfly.key -subj "$WILDFLY_SUBJECT" -out wildfly.csr

echo "Sign wildfly CSR using CA key to generate server certificate (wildfly.crt):"
openssl x509 -req -days 3650 -in wildfly.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out wildfly.crt

# PKCS12: binary format for storing a certificate chain and private key in a single, encryptable file
echo "Store Wildfly cert & key and CA cert into pkcs12 format (wildfly.pkcs12):"
openssl pkcs12 -export -in wildfly.crt -inkey wildfly.key -out wildfly.pkcs12 -name myserverkeystore -CAfile ca.crt -passin pass:$PASSWORD  -passout pass:$PASSWORD

echo "Convert Wildfly pkcs12 file to Java keystore (wildfly.keystore):"
keytool -importkeystore -deststorepass $PASSWORD -destkeypass $PASSWORD -destkeystore wildfly.keystore -srckeystore wildfly.pkcs12 -srcstoretype PKCS12 -srcstorepass $PASSWORD

cp wildfly.keystore $WILDFLY_CONFIGURATION_DIR