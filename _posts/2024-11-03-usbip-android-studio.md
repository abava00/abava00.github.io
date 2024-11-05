---
layout: post
title: "USB/IPを使ってAndroid Studioを実行する環境を構築してみる"
toc: true
---

Androidアプリを作成する予定は無いけどAndroid Studioに実機デバイス(スマホ)を接続する必要があったので、その際の環境構築の方法をまとめます。

使うときはX11フォワーディングを行ったSSHで操作するイメージ、ただし これだといちいちProxmoxのサーバにスマホを接続しにいく必要があり面倒そうだった、
なのでUSB/IPを使って、Windows環境に刺したスマホがVM上のAndroid Studioに実機デバイスとして認識されるようにした。

今回の構成だとProxmoxを用いるが、本当なら仮想環境でない環境やWSLの環境にも接続させることができるはず。

![構成図](https://private-user-images.githubusercontent.com/60212516/382787444-70be1046-6ac7-4323-a65f-5b5c01f6e656.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzA4MjI2OTYsIm5iZiI6MTczMDgyMjM5NiwicGF0aCI6Ii82MDIxMjUxNi8zODI3ODc0NDQtNzBiZTEwNDYtNmFjNy00MzIzLWE2NWYtNWI1YzAxZjZlNjU2LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDExMDUlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQxMTA1VDE1NTk1NlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWRlMWNmN2E3YTIzZmVjZDVjMjA3Y2E2N2FhM2I3ODcyMjEyYWRlMTZkMTJlMTQ0MjE2NDVkZGYyN2Q0ZjVlNTAmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.ApN8uZBAkXXsFVuX3msPHSxz2R4k3k6aN1ltMMhwHtQ)
構成図<br>*今回はプライベートアドレス空間だが、グローバルアドレス空間でも同様にできると思う。*

# 前提準備
下記が済んだ状況にする
- Windows環境 (Windows11 10.0.22631 ビルド 22631)
  - usbipd.exeのインストール
  - Xlaunch.exeのインストール
- VM環境 (Ubuntu 22.04.5 LTS [Jammy Jellyfish] )
  - usbipのインストール
  - Android Studioのインストール
  - sshのX11フォワーディングの有効化
- スマホ (Google Pixel 8a)
  - USBデバッグの有効化

# スマホ側の設定
Windows環境にUSB接続する。

今回は下記の設定項目で行っている。

| -------- | ------- |
| USBコントロール | このデバイス |
| USBの接続用途 | ファイル転送/Android Auto |


# Windows側の操作
管理者権限でPowerShellを起動してコマンドを実行していく。

今回はBUSIDが1-1のPixel 8aをUSB/IPで転送する。
もしかしてBluetoothを使って接続されたデバイスの転送できたりするのか？

```
PS > usbipd list
Connected:
BUSID  VID:PID    DEVICE                                      STATE
1-1    xxxx:xxxx  Pixel 8a                                    Not shared
1-13   yyyy:yyyy  USB 入力デバイス                            Not shared
1-14   zzzz:zzzz  インテル(R) ワイヤレス Bluetooth(R)         Not shared
...

Persisted:
GUID                                  DEVICE
aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa  Pixel 8a
bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb  Pixel 8a, ADB Interface
```

Pixel 8aを他のデバイスからアタッチできる状態にする。

STATEがsharedになっていればOK。
```
PS > usbipd.exe bind --busid=1-1
PS > usbipd list
Connected:
BUSID  VID:PID    DEVICE                      STATE
1-1    xxxx:xxxx  Pixel 8a                    shared
...

// sharedをNot sharedに戻したい場合はunbindを使う。
PS > usbipd.exe unbind --busid=1-1
```

# Linux側の操作
USB/IPのインストールと有効化を行う。
```
VM > sudo apt install linux-tools-generic linux-cloud-tools-generic linux-tools-virtual hwdata
VM > sudo modprobe vhci-hcd
```
<!-- VM > sudo modprobe usbip_host -->

Windows側で設定したデバイスをLinux側で拾うことができるか確認する。

自分でsharedにしたデバイスが出力されていればOK。何も拾えていなければ 「Exportable USB devices」以降に何も出力されない。
```
VM > sudo usbip list -r 192.168.1.X
Exportable USB devices
======================
 - 192.168.1.X
        1-1: Google Inc. : Nexus/Pixel Device (charging + debug) (xxxx:xxxx)
           : USB\VID_18D1&PID_4EE7\44444444444444
           : (Defined at Interface level) (00/00/00)
           :  0 - Vendor Specific Class / unknown subclass / unknown protocol (ff/42/01)
```

デバイスをLinuxにアタッチする。

正常にアタッチできれば何も出力されない
```
VM > sudo usbip attach -r 192.168.1.X --busid=1-1
```

## エラー対応 (Attach時にDevice busyが表示される)
アタッチした際に下記のエラーメッセージが表示され利用できないことがある。

ホストデバイスでそのUSBデバイスを利用していることが理由なので、**タスクマネージャーからadb.exeを殺した。**
バインド時に-f(Force)オプションを使えばこの操作は不要かも。
```
VM > usbip: error: Attach Request for 1-1 failed - Device busy (exported)
```

![タスクマネージャー](https://private-user-images.githubusercontent.com/60212516/382787513-39a198a8-e1a8-47d5-978a-ee37acf20f3f.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzA4MjI2OTYsIm5iZiI6MTczMDgyMjM5NiwicGF0aCI6Ii82MDIxMjUxNi8zODI3ODc1MTMtMzlhMTk4YTgtZTFhOC00N2Q1LTk3OGEtZWUzN2FjZjIwZjNmLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDExMDUlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQxMTA1VDE1NTk1NlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTJiZjM2Y2JlZWVmNDhhZmUzMDAxZmNkMGZjYTdmMDRkYjJhYzNjMDU3NWNiMTkzM2UxN2I3M2Y4ZWFlNTdjODEmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.1w3r3tBGgivyzDpeD-E30VmxMEd-x4-G2qlQ4yKsAcc)
タスクマネージャーから殺した<br>*必ず動いているわけじゃないっぽい、他にもホストでUSBデバイスを使っている場合は適宜殺す*

```
// -f オプションでバインドしなおす。
PS > usbipd.exe unbind --busid=1-1
PS > usbipd.exe bind --busid=1-1 -f
```

# 動作の確認
以上の操作でWindows側に刺したUSBデバイスがLinux側で認識される状態になったはず。

ちゃんと接続できているかを確認してみる。
```
VM > lsusb
Bus 003 Device 001: ID aaaa:aaaa Linux Foundation 3.0 root hub
Bus 002 Device 003: ID xxxx:xxxx Google Inc. Nexus/Pixel Device (charging + debug)   //今回の場合はコレ
Bus 002 Device 001: ID bbbb:bbbb Linux Foundation 2.0 root hub
Bus 001 Device 002: ID cccc:cccc Adomax Technology Co., Ltd QEMU USB Tablet
Bus 001 Device 001: ID dddd:dddd Linux Foundation 1.1 root hub
```

nautilusを使っている場合はデバイスが自動でマウントされるので表示される。
![nautilus](https://private-user-images.githubusercontent.com/60212516/382787527-21bd3536-27c9-4645-8fab-c7e836f9a67f.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzA4MjI2OTYsIm5iZiI6MTczMDgyMjM5NiwicGF0aCI6Ii82MDIxMjUxNi8zODI3ODc1MjctMjFiZDM1MzYtMjdjOS00NjQ1LThmYWItYzdlODM2ZjlhNjdmLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDExMDUlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQxMTA1VDE1NTk1NlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWI1ZWI0YTgzNGNiOTI3NWYxM2Y2YzZkMzgyNDM0ZTBkNTIzMTM4YWFhMWFjNzBhMTQxZmQ2NjM2MWEzNjZkM2YmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.RbuF2nMIwucBwCGBvufMeyiXR_PPhpU-Z_sIWCfiXFc)<br>
nautilusでの表示<br>*コマンド打つのが面倒な時は楽に確認できる*


ここまで上手くできていればAndroid Studioの Running DeviceタブからWindows環境に接続したスマホをかくにんすることができる。
![android_studio](https://private-user-images.githubusercontent.com/60212516/382787556-a6de7107-8520-43de-bd4b-cdc82b6bd4ad.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzA4MjI2OTYsIm5iZiI6MTczMDgyMjM5NiwicGF0aCI6Ii82MDIxMjUxNi8zODI3ODc1NTYtYTZkZTcxMDctODUyMC00M2RlLWJkNGItY2RjODJiNmJkNGFkLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDExMDUlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQxMTA1VDE1NTk1NlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTYyY2I1NDQ3YmFiODEzMjQ5ZjlhZjBkMGU4MWY2OWM0MzIxMmNjYjZjNDdkOTY1ODI0ODVlODFhMmQ4NTM0MTUmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.QlVlovqppZgqjY8cKZxi1ULAGdGoIqirC_cjqrim7yU)<br>
成し遂げたぜ<br>*ここまでできていればadbコマンドによる操作も同様に行える状態なっている。*
