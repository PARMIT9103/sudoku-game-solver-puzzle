include("src/puzzle/builder.jl")


s = random_puzzle(5, 550)
print(s)

solve!(s)

print(s)

new_puzzle()
