import time

start = time.time()
n = int(input())
A = []
B = []
max = 1000000
for i in range(n):
    row = list(map(float, input().split()))
    A.append(row)

for i in range(n):
    row = list(map(float, input().split()))
    B.append(row)

C = []
for _ in range(n):
    C.append(([0]*n))
for _ in range(max):
    for i in range(n):
        for j in range(n):
            temp = 0
            for k in range(n):
                temp += A[i][k] * B[k][j]
            C[i][j] = temp

for i in range(n):
    for j in range(n):
        print("%.2f" % C[i][j], end=" ")
    print()
end = time.time()
print(end - start)