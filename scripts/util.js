export const upgradeContract = async (
  account,
  proxy,
  newImplementationAddress,
  proxyAdminContract,
) => {
  if (proxyAdminContract) {
    proxyAdminContract.upgrade(proxy.address, newImplementationAddress, {
      from: account,
    });
  } else {
    proxy.upgradeTo(newImplementationAddress, { from: account });
  }
};
