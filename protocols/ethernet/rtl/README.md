Tipycally you have to generate the correspondant MAC-PHY of your device,
then you feed the mac data to the eth_fields which parse the ethernet frame
finally you could feed the ethernet payload to another protocol..
We typically use UDP and those modules are the main interface with the rest
of our system.
