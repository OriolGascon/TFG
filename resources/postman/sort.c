#include <stdio.h>
#include <string.h>
int main(){
  int n; if(scanf("%d", &n)!=1) return 1;
  char w[205][205];
  for(int i=0;i<n;i++){ if(scanf("%204s", w[i])!=1) return 1; }
  for(int i=0;i<n;i++) for(int j=i+1;j<n;j++) if(strcmp(w[i], w[j])>0){
    char tmp[205]; strcpy(tmp,w[i]); strcpy(w[i],w[j]); strcpy(w[j],tmp);
  }
  for(int i=0;i<n;i++) printf("%s\n", w[i]);
  return 0;
}
