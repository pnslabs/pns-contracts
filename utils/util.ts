const Web3 = require("web3");
const web3 = new Web3("http://localhost:8545");


const keccak256 = (...args) => {
  args = args.map((arg) => {
    if (typeof arg === "string") {
      if (arg.substring(0, 2) === "0x") {
        return arg.slice(2);
      } else {
        return web3.utils.toHex(arg).slice(2);
      }
    }

    if (typeof arg === "number") {
      return leftPad(arg.toString(16), 64, 0);
    } else {
      return "";
    }
  });

  args = args.join("");

  return web3.utils.sha3(args, { encoding: "hex" });
};

module.exports = {
  keccak256,
};
