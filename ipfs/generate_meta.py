import csv
import json


def generate_file(image_name: str, prefix: str, meta: dict):
    tokenID = meta["tokenID"]
    path = prefix + "/" + tokenID + ".json"
    # convert "attributes[XXX]" = value -> dict[XXX]=value
    attributes = []
    for (key, value) in meta.items():
        if key.startswith("attributes["):
            key = key.replace("attributes[", "").replace("]", "")
            attributes.append({"trait_type": key, "value": value})

    with open(path, "w") as f:

        data = {
            "name": meta["name"],
            "description": meta["description"],
            "external_url": meta["external_url"],
            "image": image_name,
            "attributes": attributes,
        }
        f.write(json.dumps(data, indent=2))


def generate_meta(archive: str, ipfs_hidden_path: str, ipfs_public_path: str):
    import zipfile
    hidden_meta = {
        "name": "Buildix NFT Collection",
        "description": """Welcome 1st NFT drop from Buildix project! Buildix is a fractional real estate investment platform that makes real property investments affordable for everyone.

Diverse houses in NFT Collection symbolize different objects you will find available for investing on Buildix.

There are 5 grades of NFT. The golden are Unique ones — most valuable NFT that provide a long list of privilegies for its holder:
- Priority opportunity to invest in new objects on the platform
- Exclusive access to some non-public objects with limited shares and particularly high returns
- Low transactions fee
- Buildix token reward
- Access to the private investor community
- Secret bonus
- Guaranteed NFT redemption one year after your purchase if you decide to exit the project

See you soon on Buildix website: https://buildix.xyz/
""",
        "external_url": "https://buildix.xyz",
        "image": "ipfs://bafybeihjnfzz44p2nyxszzqrsqdt4wvnelibyspkddwklv7epmqqxtkbmq",
        "attributes": [
        ]
    }
    with zipfile.ZipFile(archive) as tree:
        # Generate 
        with tree.open("ZIP/Buildix_attributes.csv") as f:
            # readfirst line and seek out
            first_line = f.readline()
            content = f.readlines()
            FIELDS = first_line.decode().strip().split(";")
            reader = csv.DictReader(map(lambda x: x.decode(), content), fieldnames=FIELDS, delimiter=";");
            for (tokenID, row) in enumerate(reader):
                # generate hidden meta
                generate_file(ipfs_hidden_path, "./hidden/", dict(tokenID=str(tokenID), **hidden_meta))
                # generate public meta
                generate_file(ipfs_public_path + "/" + row["file_name"], "./public/", row)

if __name__ == "__main__":
    import sys, os
    if len(sys.argv) != 4:
        print(f"usage: {os.path.basename(sys.argv[0])} zipfile ipfs_hidden_image_path ipfs_public_prefix")
        sys.exit(1)
    FILENAME = sys.argv[1]
    IPFS_HIDDEN_PATH = sys.argv[2]
    IPFS_PUBLIC_PATH = sys.argv[3]
    generate_meta(FILENAME, IPFS_HIDDEN_PATH, IPFS_PUBLIC_PATH)
