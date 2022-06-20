address admin {
module Bank {
    use StarcoinFramework::Signer;
    use StarcoinFramework::Token;
    use StarcoinFramework::Account;
    use StarcoinFramework::Event;


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

    public(script) fun send_token<TokenType: store>(signer: signer, to: address, amount: u128, ) acquires Bank, BankEvent {
        let _account = &signer;
        let from = DEFAULT_ADMIN;

        let _user_addr = Signer::address_of(_account);
        assert!(exists<Bank<TokenType>>(from), 1000310);
        let from_Bank = borrow_global_mut<Bank<TokenType>>(from);

        let token = Token::withdraw<TokenType>(&mut from_Bank.bank, amount);

        if ( exists<Bank<TokenType>>(to)) {
            let to_Bank = borrow_global_mut<Bank<TokenType>>(to);
            Token::deposit<TokenType>(&mut to_Bank.bank, token);
        }else {
            Account::deposit<TokenType>(to, token);
        };

        let token_event = borrow_global_mut<BankEvent<TokenType>>(from);
        Event::emit_event(&mut token_event.send_token_event_handler, SendTokenEvent{
            amount,
            from,
            to,
            token_type: Token::token_code<TokenType>()
        });
    }
}
}