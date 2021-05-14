{ config, pkgs, ... }:

{
    services.openssh.enable = true;

    users.users.root.openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA5K62E/ZFLEOIQmzKClxVAP5GmR+6ir+hWxPxK9XfvMZtTtCcnhXBnXNfQlSrX301INy9DiVfN+bRYHS3LU7TUfEcd6E5iwCOH6o9nRVZS7IkJDN/cw0m3co7cFeoayNZylIeACVfM7DwBjzzOXMV3T4hN5LbHkpv63CNTTTQqBaak+CZBQFmzMgIYGiEAi5a3yzZFpVh46JkaasDO2C9SfTNBIuCfaUIAbMbXb09B6FsirBdhndEI2fpT+1jYM0PUeqnxDbYuv5UDwDgKADo/HBAid1X4srJZzMjcnFjtwrazk3/DzyICnZM4R6xuw4cOYiDgfbfYsLYaT70YqFPUw== kaine@gestalt" 
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDH1xtRI30QFFghcJoyHVQ319TyLvKDXRjchYVv0avJOiKZ6blD2zm2iCSwm1XuwKbCLsyLAFdn+uo1uw3Df2gXI3Fe4xsEerOR0fr1NNeC27nvR8zT3obWhYbtuYE7b/xXwnCtQpDHmot3Ii45mJ0hV/p+W7u7rmnZxf6P9GFSXOntIFRx6EKEh20wnfMCsx+mEY2qmZQorAwi1cWzFQf8a8nraeeiqh/EECfGTsZS6SDxUXjm9UrtsKdMGSBdqgpUAcfZZ/97CGgzstmxO/Ff5fJK425fP6Zw73H1QdUaXANKeGDP+AceLGbgGGOR9IOsXbrHvpXd0om7AVoHpJMP"
    ];
}
