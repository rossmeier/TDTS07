N = 11
print(
    "A[] not ("
    + " or ".join(
        f"(P{i}.cs and (" + " or ".join(f"P{j}.cs" for j in range(i + 1, N + 1)) + "))"
        for i in range(1, N)
    )
    + ")"
)
