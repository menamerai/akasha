const helpers = require("@nomicfoundation/hardhat-network-helpers");

async function init() {
  const address = "0x49CbBfE64781209c13A8A862Fc8cAfa4E7a3AC5A";

  await helpers.setBalance(address, 10000);
  console.log("What");
}

init()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  