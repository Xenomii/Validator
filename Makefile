
# One of: Darwin_i386, Darwin_x86_64, Linux_i386, Linux_x86_64
BURROW_ARCH := Linux_x86_64
BURROW_VERSION := 0.34.0
BURROW_RELEASE_URL := "https://github.com/hyperledger/burrow/releases/download/v${BURROW_VERSION}/burrow_${BURROW_VERSION}_${BURROW_ARCH}.tar.gz"
# Set to 'burrow' to use whatever is on PATH instead
BURROW_BIN := bin/burrow

#
# Running the chain
#
# Make a simple single node chain
.PHONY: chain
chain: bin/burrow burrow.toml

# Get the burrow binary
/bin/burrow:
	mkdir -p bin
	curl -L ${BURROW_RELEASE_URL} | tar zx -C bin burrow

# Generate the chain
burrow.toml genesis.json:
	${BURROW_BIN} spec --full-accounts 2 | ${BURROW_BIN} configure -s- --pool --separate-genesis-doc=genesis.json
	jq  '.Accounts[] | select(.Name == "Full_0")' genesis.json > account.json

# Reset burrow state
.PHONY: reset_chain
reset_chain:
	rm -rf .burrow

# Remove burrow chain completely
.PHONY: remove_chain
remove_chain:
	rm -rf burrow.toml genesis.json .keys .burrow

# remake and reset chain
.PHONY: rechain
rechain: | remove_chain chain

.PHONY: start_chain
start_chain: chain

.PHONY: restart
restart: | rechain start_chain
