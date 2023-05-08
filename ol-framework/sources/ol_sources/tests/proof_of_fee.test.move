#[test_only]
module ol_framework::test_pof {
  use ol_framework::mock;
  use ol_framework::account;
  use ol_framework::proof_of_fee;
  use ol_framework::reconfiguration;
  use ol_framework::jail;
  use ol_framework::ol_account;
  use ol_framework::vouch;
  use aptos_framework::stake;
  use std::vector;
  use aptos_std::debug::print;


  #[test]
  fun pof_set_retract () {
    // genesis();
    
    let set = mock::genesis_n_vals(4);
    let alice = vector::borrow(&set, 0);
    stake::is_valid(*alice);

    let a_sig = account::create_signer_for_test(*alice);
    proof_of_fee::init(&a_sig);

    let (bid, expires) = proof_of_fee::current_bid(*alice);
    assert!(bid == 0, 1001);
    assert!(expires == 0, 1002);


    proof_of_fee::set_bid(&a_sig, 100, 0);
    let (bid, expires) = proof_of_fee::current_bid(*alice);
    assert!(bid == 100, 1003);
    assert!(expires == 0, 1004);


    // now retract
    proof_of_fee::retract_bid(&a_sig);
    let (bid, expires) = proof_of_fee::current_bid(*alice);
    let (is_rectracted, epoch) = proof_of_fee::is_already_retracted(*alice);
    assert!(is_rectracted, 1007);

    let this_epoch = reconfiguration::get_current_epoch();

    assert!(epoch == this_epoch, 1008);
    assert!(bid == 0, 1009);
    assert!(expires == 0, 10010);
  }

  #[test]
  fun audit_happy () {
    let set = mock::genesis_n_vals(4);
    let alice = vector::borrow(&set, 0);

    assert!(!jail::is_jailed(*alice), 1001);
    let a_sig = account::create_signer_for_test(*alice);

    proof_of_fee::set_bid(&a_sig, 1, 10000);
    let (bid, expires) = proof_of_fee::current_bid(*alice);
    assert!(bid == 1, 1001);
    assert!(expires == 10000, 1002);
    
    // ol_account::slow_wallet_epoch_drip(&vm, 500000);
    let coin = ol_account::unlocked_amount(*alice);
    let (r, _, _) = proof_of_fee::get_consensus_reward();
    let bid_cost = (bid * r) / 1000;
    assert!(coin > bid_cost, 1005);

    // should NOTE pass audit.
    assert!(proof_of_fee::audit_qualification(alice), 1006);
  }

  #[test]
  fun audit_vouch () {
    let set = mock::genesis_n_vals(4);
    let alice = vector::borrow(&set, 0);

    assert!(!jail::is_jailed(*alice), 1001);
    let a_sig = account::create_signer_for_test(*alice);

    proof_of_fee::set_bid(&a_sig, 1, 10000);
    let (bid, expires) = proof_of_fee::current_bid(*alice);
    assert!(bid == 1, 1001);
    assert!(expires == 10000, 1002);
    
    // ol_account::slow_wallet_epoch_drip(&vm, 500000);
    let coin = ol_account::unlocked_amount(*alice);
    let (r, _, _) = proof_of_fee::get_consensus_reward();
    let bid_cost = (bid * r) / 1000;
    print(&coin);
    print(&bid_cost);

    assert!(!vouch::unrelated_buddies_above_thresh(*alice), 1006);

    let bob = vector::borrow(&set, 1);
    let b_sig = account::create_signer_for_test(*bob);


    vouch::vouch_for(&b_sig, *alice);

    assert!(proof_of_fee::audit_qualification(alice), 1008);



    // assert!(coin > bid_cost, 1005);
  }

  #[test]
    fun audit_no_funds () {
    let set = mock::genesis_n_vals(4);
    let alice = vector::borrow(&set, 0);

    assert!(!jail::is_jailed(*alice), 1001);
    let a_sig = account::create_signer_for_test(*alice);

    proof_of_fee::set_bid(&a_sig, 1, 10000);
    let (bid, expires) = proof_of_fee::current_bid(*alice);
    assert!(bid == 1, 1001);
    assert!(expires == 10000, 1002);
    
    // ol_account::slow_wallet_epoch_drip(&vm, 500000);
    let coin = ol_account::unlocked_amount(*alice);
    let (r, _, _) = proof_of_fee::get_consensus_reward();
    let bid_cost = (bid * r) / 1000;
    assert!(coin < bid_cost, 1005);

    // should NOTE pass audit.
    assert!(!proof_of_fee::audit_qualification(alice), 1006);
  }

  #[test]
  fun set_bid_expired() {
    let set = mock::genesis_n_vals(4);
    let alice = vector::borrow(&set, 0);

    assert!(!jail::is_jailed(*alice), 1001);
    let a_sig = account::create_signer_for_test(*alice);

    proof_of_fee::set_bid(&a_sig, 1, 10000);
    let (bid, expires) = proof_of_fee::current_bid(*alice);
    assert!(bid == 1, 1001);
    assert!(expires == 10000, 1002);
    
    // ol_account::slow_wallet_epoch_drip(&vm, 500000);
    let coin = ol_account::unlocked_amount(*alice);
    let (r, _, _) = proof_of_fee::get_consensus_reward();
    let bid_cost = (bid * r) / 1000;
    assert!(coin > bid_cost, 1005);


    // has a bid which IS expired
    // test runner is at epoch 1, they put expiry at 0.
    // TODO: Improve this test by doing more advanced epochs
    proof_of_fee::set_bid(&a_sig, 1, 0); 
    let (bid, expires) = proof_of_fee::current_bid(*alice);
    assert!(bid == 1, 1006);
    assert!(expires == 0, 1007);
    // should NOT pass audit.
    assert!(!proof_of_fee::audit_qualification(alice), 1008);

    // fix it
    proof_of_fee::set_bid(&a_sig, 1, 1000); 
    assert!(proof_of_fee::audit_qualification(alice), 1009);
  }

  #[test]

  fun audit_jail () {
    let set = mock::genesis_n_vals(4);
    let alice = vector::borrow(&set, 0);

    assert!(!jail::is_jailed(*alice), 1001);
    let a_sig = account::create_signer_for_test(*alice);

    proof_of_fee::set_bid(&a_sig, 1, 10000);
    let (bid, expires) = proof_of_fee::current_bid(*alice);
    assert!(bid == 1, 1001);
    assert!(expires == 10000, 1002);
    
    // ol_account::slow_wallet_epoch_drip(&vm, 500000);
    let coin = ol_account::unlocked_amount(*alice);
    let (r, _, _) = proof_of_fee::get_consensus_reward();
    let bid_cost = (bid * r) / 1000;
    assert!(coin > bid_cost, 1005);

    // EVERYTHING ABOVE HERE IS PASSING.
    // is now jailed.
    jail::jail(&vm, *alice);
    assert!(jail::is_jailed(*alice), 1006);
    // won't pass audit
    assert!(!proof_of_fee::audit_qualification(&*alice), 1007);
    
  }
}