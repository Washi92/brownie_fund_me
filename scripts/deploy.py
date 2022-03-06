from ssl import VerifyFlags
from brownie import FundMe, network, config, MockV3Aggregator
from scripts.tools import get_account, deploy_mocks, LOCAL_BLOCKCHAIN_ENVIRONMENTS


def deploy_fund_me():
    account = get_account()
    # We verify our contract and pubblish our source code
    # We need to pass also the price feeed address to our fundMe contract

    # If persistant network (eg. rinkeby) -> hardcode address
    # else -> deploy mocks
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        deploy_mocks()
        # use the most recent deployed MockV3Aggregator
        price_feed_address = MockV3Aggregator[-1].address

    fund_me = FundMe.deploy(
        price_feed_address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )
    print(f"Contract deployed to {fund_me.address}")
    return fund_me


def main():
    deploy_fund_me()
