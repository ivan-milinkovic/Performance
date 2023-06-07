while IFS= read -r line; do
    # echo "$line"
    echo $line
    echo "bits 16\n\n$line\n" > test.asm
    `nasm test.asm` && xxd -b "test"
done < "test2.asm"
