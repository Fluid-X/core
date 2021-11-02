const HDWalletProvider = require('@truffle/hdwallet-provider')
require('dotenv').config()
const GAS_LIMIT = 8e6

module.exports = {
    networks: {
        goerli: {
            provider: () => new HDWalletProvider(
                process.env.GOERLI_MNEMONIC,
                process.env.GOERLI_PROVIDER_URL
            ),
            network_id: 5,
            gas: GAS_LIMIT,
            gasPrice: 10e9,
            timeoutBlocks: 50,
            skipDryRun: false
        },
        ganache: {
            host: '127.0.0.1',
            network_id: '*',
            port: process.env.GANACHE_PORT || 8545
        }
    },
    mocha: {
        timeout: 100000
    },
    compilers: {
        solc: {
            version: '0.8.9'
        }
    }
}
