address admin {
module GameShowdown {
    use StarcoinFramework::Account;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Errors;
    use SFC::PseudoRandom;

    const INVALID_SIGNER_BALANCE: u64 = 1;
    const INVALID_CONTRACT_BALANCE: u64 = 2;
    const DEFAULT_ADMIN: address = @admin;


    struct Bank<phantom T: store> has store, key {
        bank: Token::Token<T>
    }

    struct SendTokenEvent has store, drop {
        amount: u128,
        from: address,
        to: address,
        token_type: Token::TokenCode
    }

    struct WithdrawTokenEvent has store, drop {
        amount: u128,
        from: address,
        to: address,
        token_type: Token::TokenCode
    }

    struct DepositTokenEvent has store, drop {
        amount: u128,
        from: address,
        to: address,
        token_type: Token::TokenCode
    }

    struct BankEvent<phantom T: store> has store, key {
        send_token_event_handler: Event::EventHandle<SendTokenEvent>,
        withdraw_token_event_handler: Event::EventHandle<WithdrawTokenEvent>,
        deposit_token_event_handler: Event::EventHandle<DepositTokenEvent>,
    }


    public(script) fun init_bank<TokenType: store>(signer: signer, amount: u128) {
        let account = &signer;
        let user_addr = Signer::address_of(account);
        assert!(user_addr == DEFAULT_ADMIN, 10003);
        assert!(! exists<Bank<TokenType>>(user_addr), 10003);
        assert!(Account::balance<TokenType>(user_addr) >= amount, 10004);
        let token = Account::withdraw<TokenType>(account, amount);
        move_to(account, Bank<TokenType>{
            bank: token
        });

        move_to(account, BankEvent<TokenType>{
            send_token_event_handler: Event::new_event_handle<SendTokenEvent>(account),
            withdraw_token_event_handler: Event::new_event_handle<WithdrawTokenEvent>(account),
            deposit_token_event_handler: Event::new_event_handle<DepositTokenEvent>(account),
        });
    }

    /// admin withdraw from bank
    public(script)  fun withdraw<TokenType: store>(signer: signer, amount: u128) acquires Bank, BankEvent {
        let account = &signer;
        let user_addr = Signer::address_of(account);
        assert!(user_addr == DEFAULT_ADMIN, 10003);
        assert!(exists<Bank<TokenType>>(user_addr), 1000310);
        let bank = borrow_global_mut<Bank<TokenType>>(user_addr);
        let token = Token::withdraw<TokenType>(&mut bank.bank, amount);
        Account::deposit<TokenType>(user_addr, token);
    }



    fun win_token<TokenType: store>(signer: signer, amount: u128) acquires Bank, BankEvent {
        let account = &signer;
        let user_addr = Signer::address_of(account);
        assert!(exists<Bank<TokenType>>(user_addr), 1000310);
        let bank = borrow_global_mut<Bank<TokenType>>(user_addr);
        let token = Token::withdraw<TokenType>(&mut bank.bank, amount);
        Account::deposit<TokenType>(user_addr, token);
    }

    fun loss_token<TokenType: store>(signer: signer, amount: u128) acquires Bank, BankEvent {
        let account = &signer;
        let user_addr = Signer::address_of(account);
        let token = Account::withdraw<TokenType>(account, amount);
        if ( exists<Bank<TokenType>>(user_addr)) {
            let bank = borrow_global_mut<Bank<TokenType>>(user_addr);
            Token::deposit<TokenType>(&mut bank.bank, token);
        }else {
            move_to(account, Bank<TokenType>{
                bank: token
            });
        };
    }

    /// check game
    public(script) fun check<TokenType: store>(_account: signer, amount: u128, input: bool) acquires Bank, BankEvent {
        let signer_addr = Signer::address_of(&_account);

        assert!(Account::balance<TokenType>(signer_addr) < amount, Errors::custom(INVALID_SIGNER_BALANCE));
        // can't all in admin balance  max only   1/10  every times
        assert!(Account::balance<TokenType>(DEFAULT_ADMIN) < amount * 10, Errors::custom(INVALID_CONTRACT_BALANCE));

        let result = getRandBool();
        if (result == input) {
            win_token<TokenType>(_account, amount)
        }else {
            loss_token<TokenType>(_account, amount)
        }
    }

    fun getRandBool(): bool {
        PseudoRandom::rand_u64(&DEFAULT_ADMIN) % 2 == 1
    }
}
}