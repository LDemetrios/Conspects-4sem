#ifndef UTILS_H
#define UTILS_H
#include <iostream>
#include <vector>

template <class T>
std::ostream& operator<<(std::ostream& out, std::vector<T>& v) {
    out << '[';
    for (size_t i = 0; i < v.size(); i++) {
        if (i != 0) out << ' ';
        out << v[i];
    }
    out << ']';
    return out;
}

void print();

template <class A, class... Args>
void print(A&& a, Args&&... args) {
    std::cout << a;
    print(std::forward<Args>(args)...);
}

template <class... Args>
void println(Args&&... args) {
    print(std::forward<Args>(args)...);
    std::cout << std::endl;
}

std::string  wErrorCode(int code);

#endif //UTILS_H
