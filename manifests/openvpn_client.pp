# == Class: role_logging::openvpn_client
#
class role_logging::openvpn_client (
  $openvpn_client_hash,
) {

  create_resources('openvpn_client::client', $openvpn_client_hash)

}
