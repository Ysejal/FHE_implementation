load("homomorphic_functions.sage")


# a left shift of SHIFT to the left,
# the new element of the right are
# encrypts of 0
# bonus idea: do not create error vector
# for the encrypt of the 0 that are
# added
def left_shift(params, public_key, list_bit, shift):
    return list_bit[shift:] + [encrypt(params, public_key, 0) for i in
                               range(shift)]


# a right shift of SHIFT to the right,
# the new element of the left are
# encrypts of 0
# bonus idea: do not create error vector
# for the encrypt of the 0 that are
# added
def right_shift(params, public_key, list_bit, shift):
    return [encrypt(params, public_key, 0) for i in range(shift)] + list_bit[:-shift]


# input: a, b lists of encryptions of 0 and 1
# of same size
# output: the homomorphic sum (modulo 2^(len(a))))
# commentary:
# It is the classic sum of 2 elements,
# in the form of list of encrypted 0
# and 1
# We ignore any carry propagation beyond the
# lenght of a (we need to have len(a) == len(b))
# (so it is modulo 2^(len(a))
def bit_sum(params, a, b):
    length = len(a)
    if (length == 1):
        return [h_XOR(params, a[0], b[0])]
    result = []
    # we look from right to left
    for i in range(length):
        # no carry
        # with 8 NAND
        if i == 0:
            carry1 = h_AND(params, a[length-1], b[length-1])
            result.insert(0, h_XOR(params, a[length-1], b[length-1]))
        # for the first element of the lists we don't care of the carry
        # with 12 NAND
        elif i == length-1:
            temp = h_XOR(params, a[0], b[0])
            result.insert(0, h_XOR(params, temp, carry1))
        # the generic case
        # with 19 NAND
        else:
            carry2 = h_AND(params, a[length-(i+1)], b[length-(i+1)])
            temp = h_XOR(params, a[length-(i+1)], b[length-(i+1)])
            carry3 = h_AND(params, temp, carry1)
            result.insert(0, h_XOR(params, temp, carry1))
            carry1 = h_OR(params, carry2, carry3)
    return result


# input: a, b, c lists of encryptions of 0 and 1
# of same size
# output: u and v lists of encryptions of 0 and 1
# of same size than a, such that
# considering the clears decimals values cu, cv, ca..
# cu + cv = ca + cb + cc mod 2^(len(a))
def reduction_sum(params, public_key, a, b, c):
    length = len(a)
    if (length == 1):
        return [h_XOR(params, a[0], b[0])], [c[0]]
    list1 = []
    list2 = []
    for i in range(length):
        # 12 NAND
        if i == 0:
            list2.insert(0, encrypt(params, public_key, 0))
            xor = h_XOR(params, b[length-1], c[length-1])
            list1.insert(0, h_XOR(params, a[length-1], xor))
        # 37 NAND
        else:
            xor = h_XOR(params, b[length-(i+1)], c[length-(i+1)])
            list1.insert(0, h_XOR(params, a[length-(i+1)], xor))
            temp1 = h_OR(params, a[length-i], b[length-i])
            temp1 = h_NO(params, temp1)
            temp2 = h_OR(params, b[length-i], c[length-i])
            temp2 = h_NO(params, temp2)
            temp3 = h_OR(params, a[length-i], c[length-i])
            temp3 = h_NO(params, temp3)
            xor = h_XOR(params, temp1, temp2)
            negation = h_XOR(params, xor, temp3)
            list2.insert(0, h_NO(params, negation))
    return list1, list2


# input: a is a list of encrypted 0 or 1
# k is an integer
# output: round(ca / 2^k)
# where ca is the decimal clear value of a
def round_division(params, a, k):
    return