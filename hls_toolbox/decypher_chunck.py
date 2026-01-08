import requests
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

def decrypt_hls_chunk(chunk_url, key_url, output_path):
    """
    Decrypts an AES-128 encrypted HLS chunk manually.

    Args:
        chunk_url (str): URL of the encrypted chunk.
        key_url (str): URL to download the AES key.
        output_path (str): Path to save the decrypted chunk.

    Returns:
        str: Path to the decrypted chunk.
    """
    try:

        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.5993.88 Safari/537.36'
        }
        # Download the AES key
        response = requests.get(key_url, headers=headers)
        response.raise_for_status()
        key = response.content  # Raw AES key content

        # Verify that the key size is 16 bytes (128 bits)
        if len(key) != 16:
            raise ValueError("The AES key is not 16 bytes (128 bits).")

        # Download the encrypted chunk
        print(f"Downloading the chunk from: {chunk_url}")
        chunk_response = requests.get(chunk_url, headers=headers,stream=True)
        chunk_response.raise_for_status()
        encrypted_data = b"".join(chunk_response.iter_content(chunk_size=8192))

        # Extract the IV (initialization vector) from the first 16 bytes and the rest as encrypted data
        iv = encrypted_data[:16]  # Initialization vector
        cipher_data = encrypted_data[16:]  # Encrypted content

        # Decrypt the data using AES-128-CBC
        cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
        decryptor = cipher.decryptor()
        decrypted_data = decryptor.update(cipher_data) + decryptor.finalize()

        # Save the decrypted chunk to the output file
        with open(output_path, "wb") as output_file:
            output_file.write(decrypted_data)

        print(f"Chunk successfully decrypted and saved to: {output_path}")
        return output_path

    except Exception as e:
        print(f"Error: {e}")
        return None

# Example usage
if __name__ == "__main__":
    # URL of the encrypted chunk
    chunk_url = "https://example.com/encrypted_chunk.ts"
    
    # URL of the AES key
    key_url = "https://example.com/keyfile.key"
    
    # Output path for the decrypted chunk
    output_path = "chunk_decrypted.ts"
    
    # Decrypt the chunk
    decrypt_hls_chunk(chunk_url, key_url, output_path)
