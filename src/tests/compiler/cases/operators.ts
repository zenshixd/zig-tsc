1 + 2;
1 - 2;
1 * 2;
1 / 2;
1 % 2;
1 ** 2;

1 + 2 * 3;
1 - 2 * 3;
1 * 2 * 3;
1 / 2 * 3;
1 % 2 * 3;

1 + 2 / 3;
1 - 2 / 3;
1 * 2 / 3;
1 / 2 / 3;
1 % 2 / 3;

1 + 2 % 3;
1 - 2 % 3;
1 * 2 % 3;
1 / 2 % 3;
1 % 2 % 3;

1 + 2 + 3;
1 - 2 - 3;
1 * 2 * 3;
1 / 2 / 3;
1 % 2 % 3;

1 + 2 - 3;
1 - 2 + 3;
1 * 2 / 3;
1 / 2 * 3;
1 % 2 % 3;

const a = {
    b: 1,
};
a.b;
a["b"];

const b = [1,2,3];
b[0];
b[1];
b[2];

a.b + b[0];
a.b - b[0];
a.b * b[0];
a.b / b[0];
a.b % b[0];
a.b ** b[0];
(a, b)[0];
(b, a).b;