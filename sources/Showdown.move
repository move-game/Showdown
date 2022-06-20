address admin {
module GameShowdown {
    use StarcoinFramework::Account;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Errors;
    use SFC::PseudoRandom;
    use admin::Bank;

    const INVALID_SIGNER_BALANCE: u64 = 1;
    const INVALID_CONTRACT_BALANCE: u64 = 2;
    const DEFAULT_ADMIN: address = @admin;


    public(script) fun check<TokenType: store>(_account: signer, amount: u128, input: bool) {
        let signer_addr = Signer::address_of(&_account);

        assert!(Account::balance<TokenType>(signer_addr) < amount, Errors::custom(INVALID_SIGNER_BALANCE));
        // can't all in admin balance  max only   1/10  every times
        assert!(Account::balance<TokenType>(DEFAULT_ADMIN) < amount * 10, Errors::custom(INVALID_CONTRACT_BALANCE));

        let result = getRandBool();
        if (result == input) {
            Bank::send_token<TokenType>(_account,signer_addr,amount)
        }
        else {
            Account::pay_from<TokenType>(&_account, DEFAULT_ADMIN, amount)
        }
    }

    fun getRandBool(): bool {
        PseudoRandom::rand_u64(&DEFAULT_ADMIN) % 2 == 1
    }
}
}