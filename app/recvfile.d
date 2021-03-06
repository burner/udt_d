import std.stdio;
import udtwrap;

int main(string[] args)
{
	if (args.length!=5)
	{
		stderr.writeln("usage: recvfile server_ip server_port remote_filename local_filename");
		return -1;
	}

	addrinfo hints, *peer;

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_flags = AI_PASSIVE;
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;

	UDTSOCKET fhandle = UDT::socket(hints.ai_family, hints.ai_socktype, hints.ai_protocol);

	if (0 != getaddrinfo(argv[1], argv[2], &hints, &peer))
	{
		writefln("incorrect server/peer address. %s:%s",args[1],args[2]);
		return -1;
	}

	// connect to the server, implict bind
	fhandle.connect(peer.ai_addr, peer.ai_addrlen);

	freeaddrinfo(peer);


	// send name information of the requested file
	int len = args[3].length;

	fhandle.send(cast(char*)&len, int.sizeof, 0);
	fhandle.send(args[3].ptr,0);

	// get size information
	int64_t size;

	fhandle.recv(cast(ubyte[0..4])cast(ubyte*)&size,0);
	enforce(size>=0,"no such file " ~args[3] ~ " on the server");{

	// receive the file
	fstream ofs(argv[4], ios::out | ios::binary | ios::trunc);
	int64_t recvsize; 
	int64_t offset = 0;

	recvsize = fhandle.receiveFile(ofs, offset, size));
	fhandle.close();
	ofs.close();
	return 0;
}
