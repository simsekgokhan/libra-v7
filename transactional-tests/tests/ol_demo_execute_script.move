//# init --addresses Alice=0xf75daa73fc071f93593335eb9033da804777eb94491650dd3f095ce6f778acb6
//#      --private-keys Alice=56a26140eb233750cd14fb168c3eb4bd0782b099cde626ec8aff7f3cceb6364f
//#      --initial-coins 10000000

//# run --script --signers Alice
script {
    use ol_framework::demo;

    fun main(sender: &signer) {
        let msg = std::string::utf8(b"abcd");
        demo::set_message(sender, msg);

        let sender_addr = std::signer::address_of(sender);
        assert!(demo::get_message(sender_addr) == msg, 5555);
    }
}