address admin {
module GameShowdown {
    use StarcoinFramework::Account;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Token;
    use StarcoinFramework::Event;
    use StarcoinFramework::Errors;
    use SFC::PseudoRandom;

    const INVALID_SIGNER_BALANCE: u64 = 1;
    const INVALID_CONTRACT_BALANCE: u64 = 2;
    const ADMIN: address = @admin;

    struct Bank<phantom T: store> has store, key {
        bank: Token::Token<T>
    }

    struct CheckEvent has store, drop {
        amount: u128,
        result: bool,
        input: bool,
        token_type: Token::TokenCode
    }

    struct BankEvent<phantom T: store> has store, key {
        check_event: Event::EventHandle<CheckEvent>,
    }

    /// admin init back
    public(script) fun init_bank<TokenType: store>(signer: signer, amount: u128) {
        let account = &signer;
        let user_addr = Signer::address_of(account);
        assert!(user_addr == ADMIN, 10003);
        assert!(! exists<Bank<TokenType>>(user_addr), 10004);
        assert!(Account::balance<TokenType>(user_addr) >= amount, 10005);
        let token = Account::withdraw<TokenType>(account, amount);
        move_to(account, Bank<TokenType>{
            bank: token
        });

        move_to(account, BankEvent<TokenType>{
            check_event:       Event::new_event_handle<CheckEvent>(account),
        });
    }

    /// admin withdraw from bank
    public(script) fun withdraw<TokenType: store>(signer: signer, amount: u128) acquires Bank {
        let user_addr = Signer::address_of(&signer);
        assert!(user_addr == ADMIN, 10003);
        assert!(exists<Bank<TokenType>>(user_addr), 10004);
        let bank = borrow_global_mut<Bank<TokenType>>(user_addr);
        let token = Token::withdraw<TokenType>(&mut bank.bank, amount);
        Account::deposit<TokenType>(user_addr, token);
    }

    /// everyone can deposit amount to bank
    public(script) fun deposit<TokenType: store>(signer: signer, amount: u128)  acquires Bank{
        let token = Account::withdraw<TokenType>( &signer, amount);
        let bank = borrow_global_mut<Bank<TokenType>>(ADMIN);
        Token::deposit<TokenType>(&mut bank.bank, token);
    }


    fun win_token<TokenType: store>(signer: signer, amount: u128) acquires Bank {
        let bank = borrow_global_mut<Bank<TokenType>>(ADMIN);
        let token = Token::withdraw<TokenType>(&mut bank.bank, amount);
        Account::deposit<TokenType>(Signer::address_of(&signer), token);
    }

    fun loss_token<TokenType: store>(signer: signer, amount: u128) acquires Bank {
        let token = Account::withdraw<TokenType>( &signer, amount);
        let bank = borrow_global_mut<Bank<TokenType>>(ADMIN);
        Token::deposit<TokenType>(&mut bank.bank, token);
    }

    /// get result for this
    fun getRandBool(): bool {
        PseudoRandom::rand_u64(&ADMIN) % 2 == 1
    }

    /// check game result
    public(script) fun check<TokenType: store>(_account: signer, amount: u128, input: bool) acquires Bank, BankEvent {

        let signer_addr = Signer::address_of(&_account);

        assert!(Account::balance<TokenType>(signer_addr) > amount, Errors::custom(INVALID_SIGNER_BALANCE));
        // can't all in admin balance  max only   1/10  every times
        assert!(Account::balance<TokenType>(ADMIN) >= amount * 10, Errors::custom(INVALID_CONTRACT_BALANCE));

        let result = getRandBool();
        if (result == input) {
            win_token<TokenType>(_account, amount)
        }else {
            loss_token<TokenType>(_account, amount)
        };

        let bank_event = borrow_global_mut<BankEvent<TokenType>>(ADMIN);
        Event::emit_event(&mut bank_event.check_event, CheckEvent{
            amount,
            result,
            input,
            token_type: Token::token_code<TokenType>()
        });
    }


}
}