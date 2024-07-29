# socks5-for-serv00
Installation scripts for Socks5 on Serv00

## 一键脚本
- nohup模式
```bash
bash <(curl -s https://raw.githubusercontent.com/cmliu/socks5-for-serv00/main/install-socks5.sh)
```

- pm2模式
```bash
bash <(curl -s https://raw.githubusercontent.com/cmliu/socks5-for-serv00/main/install-socks5-pm2.sh)
```

## Github Actions保活
添加 Secrets.`ACCOUNTS_JSON` 变量
```json
[
  {"username": "cmliusss", "password": "7HEt(xeRxttdvgB^nCU6", "panel": "panel4.serv00.com", "ssh": "s4.serv00.com"},
  {"username": "cmliussss2018", "password": "4))@cRP%HtN8AryHlh^#", "panel": "panel7.serv00.com", "ssh": "s7.serv00.com"},
  {"username": "4r885wvl", "password": "%Mg^dDMo6yIY$dZmxWNy", "panel": "panel.ct8.pl", "ssh": "s1.ct8.pl"}
]
```

# 致谢
[RealNeoMan](https://github.com/Neomanbeta/ct8socks)、[k0baya](https://github.com/k0baya)、[eooce](https://github.com/eooce)
