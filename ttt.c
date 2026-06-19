#include <stdio.h>

char b[9] = "123456789";

void pr() {
	printf("\n %c|%c|%c\n---+---+---\n %c|%c|%c\n---+---+---\n %c|%c|%c\n\n",
		b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8]);
}

int w(char p) {
	int m[8][3] = {{0,1,2},{3,4,5},{6,7,8},{0,3,6},
		       {1,4,7},{2,5,8},{0,4,8},{2,4,6}};
	for(int i=0;i<8;i++)
	    if(b[m[i][0]]==p && b[m[i][1]]==p && b[m[i][2]]==p) return 1;
	return 0;
}

int main() {
	char p='X'; int m, t=0;
	while(t<9) {
		pr();
		printf("Ход %c(1-9):", p);
		scanf("%d", &m);
		if(m<1 || m>9 ||b[m-1=='X' ||b[m-1=='O']]) continue;
		b[m-1] = p; t++;
		if(w(p)) { pr(); printf("%c выйграл!\n", p); return 0; }
		p = p=='X' ? 'O' : 'X';
	}

	pr(); printf("Ничья!\n"); return 0;
} 
