const { withEntitlementsPlist } = require("@expo/config-plugins");

module.exports = function withoutIosPushNotifications(config) {
  return withEntitlementsPlist(config, (configuredConfig) => {
    delete configuredConfig.modResults["aps-environment"];
    return configuredConfig;
  });
};
