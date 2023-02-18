import { ethers } from 'ethers';

const privateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

describe('PNS Resolver', () => {
  before(async () => {
    const provider = await new ethers.providers.JsonRpcProvider('http://localhost:8545');
    // const provider = await ethers.getDefaultProvider(rpc);
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const signer = await new ethers.Wallet(privateKey!, provider);

    //   pns = await new PNS(provider, signer);
    console.log('pns', provider.connection);
  });

  it('fire', async () => {
    // console.log('pns', provider);
  });
});
