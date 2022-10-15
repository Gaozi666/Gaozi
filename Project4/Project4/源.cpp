#include <stdio.h>
int main(void) {
	int a, b;
	printf("input two diffrent numbers.");
	scanf_s("%d %d", &a, &b);
	if (a > b) {
		printf("the number is %d",a);
	}
	else {
		printf("the number is %d",b);
	}
	return 0;
}
