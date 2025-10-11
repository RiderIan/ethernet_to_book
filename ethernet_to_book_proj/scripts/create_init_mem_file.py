##################################################################################
## Dev: Ian Rider
## Purpose: Generates inital ram contents
##################################################################################

filename = "src/reuse/init_ram_zeros.mem"
lines = 2048
width = 64
fill  = 0

hexNums = width // 4

with open(filename, "w") as file:
    for _ in range(lines):
        file.write(f"{fill:0{hexNums}X}\n")