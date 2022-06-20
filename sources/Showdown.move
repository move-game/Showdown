address admin {
module GameShowdown {
    use StarcoinFramework::Account;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Errors;
    use SFC::PseudoRandom;

    const INVALID_SIGNER_BALANCE: u64 = 1;
    const INVALID_CONTRACT_BALANCE: u64 = 2;
    const DEFAULT_ADMIN: address = @admin;

    /// amount 压注金额
    /// input 压注内容   true 压结果为大     false 压结果为小
    /// 最大值只能压 合约账户的 10 分之一的余额 防止 all in 掉合约账户
    public(script) fun check<TokenType: store>(_account: signer, amount: u128, input: bool) acquires Balance, Account {
        let signer_addr = Signer::address_of(&_account);
        // 判断发起人的余额
        assert!(Account::balance<TokenType>(signer_addr) < amount, Errors::custom(INVALID_SIGNER_BALANCE));
        // 判断合约余额  最大值只能压 合约账户的 10 分之一的余额
        assert!(Account::balance<TokenType>(DEFAULT_ADMIN) < amount * 10, Errors::custom(INVALID_CONTRACT_BALANCE));


        let result = getRandBool();
        if (result == input) {
            // 处理压中的逻辑
            Account::pay_from<TokenType>(&DEFAULT_ADMIN, signer_addr, amount)
        }
        else {
            // 处理未压中的逻辑
            Account::pay_from<TokenType>(&signer_addr, DEFAULT_ADMIN, amount)
        }
    }

    /// 合约地址取随机数   true 结果为大  false 结果为小
    fun getRandBool(): bool {
        PseudoRandom::rand_u64(Showdown) % 2 == 1
    }
}
}