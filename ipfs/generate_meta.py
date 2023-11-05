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
    with zipfile.ZipFile(archive) as tree:
        # Generate 
        with tree.open("ZIP/Buildix_attributes.csv") as f:
            # readfirst line and seek out
            first_line = f.readline()
            content = f.readlines()
            FIELDS = first_line.decode().strip().split(";")
            reader = csv.DictReader(map(lambda x: x.decode(), content), fieldnames=FIELDS, delimiter=";");
            for row in reader:
                # generate hidden meta
                generate_file(ipfs_hidden_path, "./hidden/", row)
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
