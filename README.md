#### Simple Java SSL/TSL Socket Server 

##### 1. What is the role of public key and private key

* Public key is used to encrypt information. 
* Private key is used to decrypt information. 

##### 2. What is the difference between digital signature and encryption

* When encrypting, you(client) use their public key to write message, and they(server) use their private key to decrypt to read it. 
* When signing, you(client) use your own private key to write message’s signature, and they(server) use your public key to verify if the message is yours. 

##### 3. What is the difference between keystore and truststore

* A keystore has certs and keys in it and defines what is going to be presented to the other end of a connection.
* A truststore has just certs in it and defines what certs that the other end will send are to be trusted. 

##### 4. The standard handshake for SSL/TSL

he standard SSL Handshake

1. Client Hello (Information that the server needs to communicate with the client using SSL.)  
   * SSL version Number 
   * Cipher setting (Compression Method) 
   * Session-specific Data 
2. Server Hello  
   * Server picks a cipher and compression that both client and server support and tells the client about its choice, as well as some other things like a session id. 
   * Server presents its certificate ( This is what client needs to validate as being signed by a trusted CA.) 
   * Server presents a list of certificate authority DNs that client certs may be signed by. 
3. Client response 
   * Client continues the key exchange protocol necessary to set up a TLS session. 
   * Client presents a certificate that was signed by one of the CAs and encrypts with the server’s public key.  
   * Send the pre-master (based on cipher) encrypted by Server’s public key to server. 
4. Server accepts the cert presented by client. 
   * Server uses its private key to decrypt the pre-master secret. Both client and server perform steps to generate the master secret with the agreed cipher. 
5. Encryption with Session Key.  
   * Both client and server exchange messages to inform that future messages will be encrypted. 

##### 5.In this simple demo, it demonstrates how to start a very simple SSL/TSL Client & server. 

* Step 1. Create a private key and public certificate for client & server by openssl tool.

```bash
openssl req -newkey rsa:2048 -nodes -keyout client-key.pem -x509 -days 365 -out client-certificate.pem
```

```bash
openssl req -newkey rsa:2048 -nodes -keyout server-key.pem -x509 -days 365 -out server-certificate.pem
```

* Step 2. Combine the private key and public certificate into `PCKS12(P12)` format for client and server respectively. 

```bash
openssl pkcs12 -inkey client-key.pem -in client-certificate.pem -export -out client-certificate.p12
```

```bash
openssl pkcs12 -inkey server-key.pem -in server-certificate.pem -export -out server-certificate.p12
```

* Step 3. Place `client-certificate.p12` and `server-certificate.p12` into `keystore` and `trustStore` location.

  ![client-server](img/client-server.jpg)

##### 6. If everything went well, you will see this:

![result](img/result.jpg)

##### 7. Instructions for enabling mutual SSL in Keycloak and WildFly

https://gist.github.com/gyfoster/4005353b1f063b92dd77798a6fbfc018

```shell
ROOT CA
--------------
Generate the CA private key:
$ openssl genrsa -out ca.key 2048

Create and self sign the root certificate:
$ openssl req -new -x509 -key ca.key -out ca.crt

Import root CA certificate into truststore:
$ keytool -import -file ca.crt -keystore ca.truststore -keypass <password> -storepass <password>


WILDFLY
-----------
Generate wildfly server key:
$ openssl genrsa -out wildfly.key 2048

Generate wildfly certificate signing request:
$ openssl req -new -key wildfly.key -out wildfly.csr

Sign wildfly CSR using CA key to generate server certificate:
$ openssl x509 -req -days 3650 -in wildfly.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out wildfly.crt

Convert WildFly cert to pkcs12 format:
$ openssl pkcs12 -export -in wildfly.crt -inkey wildfly.key -out wildfly.p12 -name myserverkeystore -CAfile ca.crt

Convert WildFly pkcs12 file to Java keystore:
$ keytool -importkeystore -deststorepass <password> -destkeypass <password> -destkeystore wildfly.keystore -srckeystore wildfly.p12 -srcstoretype PKCS12 -srcstorepass <password>


KEYCLOAK
-------------
Generate keycloak server key:
$ openssl genrsa -out keycloak.key 2048

Generate keycloak certificate signing request:
$ openssl req -new -key keycloak.key -out keycloak.csr

Sign keycloak CSR using CA key to generate server certificate:
$ openssl x509 -req -days 3650 -in keycloak.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out keycloak.crt

Convert Keycloak cert to pkcs12 format:
$ openssl pkcs12 -export -in keycloak.crt -inkey keycloak.key -out keycloak.p12 -name myserverkeystore -CAfile ca.crt

Convert Keycloak pkcs12 file to Java keystore:
$ keytool -importkeystore -deststorepass <password> -destkeypass <password> -destkeystore keycloak.keystore -srckeystore keycloak.p12 -srcstoretype PKCS12 -srcstorepass <password>


CLIENT (browser)
------------------
Generate client server key:
$ openssl genrsa -out client.key 2048

Generate client certificate signing request:
$ openssl req -new -key client.key -out client.csr

Sign client CSR using CA key to generate server certificate:
$ openssl x509 -req -days 3650 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt

Export client certificate to pkcs12 format:
$ openssl pkcs12 -export -in client.crt -inkey client.key -certfile ca.crt -out clientCert.p12


FINAL STEPS
------------
1. Import clientCert.p12 into browser
2. Paste wildfly.keystore and ca.truststore into WILDFLY_HOME\standalone\configuration
3. Paste keycloak.keystore and ca.truststore into KEYCLOAK_HOME\standalone\configuration
4. Paste the following inside security-realms in WILDFLY_HOME\standalone\configuration\standalone.xml:
    <security-realm name="ssl-realm">
      <server-identities>
        <ssl>
          <keystore path="wildfly.keystore" relative-to="jboss.server.config.dir" keystore-password="secret" alias="myserverkeystore" key-password="<password>" />
        </ssl>
      </server-identities>
      <authentication>
        <truststore path="ca.truststore" relative-to="jboss.server.config.dir" keystore-password="<password>" />
      </authentication>
    </security-realm>
5. Paste the following inside security-realms in KEYCLOAK_HOME\standalone\configuration\standalone.xml:
    <security-realm name="ssl-realm">
      <server-identities>
        <ssl>
          <keystore path="keycloak.keystore" relative-to="jboss.server.config.dir" keystore-password="secret" alias="myserverkeystore" key-password="<password>" />
        </ssl>
      </server-identities>
      <authentication>
        <truststore path="ca.truststore" relative-to="jboss.server.config.dir" keystore-password="<password>" />
      </authentication>
    </security-realm>
6. Replace https-listener with the following in WildFly's and Keycloak's standalone.xml:
    <https-listener name="https" socket-binding="https" security-realm="ssl-realm" enable-http2="true" verify-client="REQUESTED" />
7. Add the following properties to your app's keycloak.json:
    ...
    "truststore": "C:\your\truststore\path\ca.truststore",
    "truststore-password": "<password>",
    ...
```
