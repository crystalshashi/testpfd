if grep -q "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto" "/etc/profile"; then
  echo "\"export JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto\" already exists in /etc/profile, skipping."
else
  echo "Appending \"export JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto\" to the end of /etc/profile"
  echo "" >> /etc/profile
  echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto" >> /etc/profile
  source /etc/profile
fi