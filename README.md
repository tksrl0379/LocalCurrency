# :round_pushpin: LocalCurrency


* ## 사용 프레임워크
RxSwift, Realm, Naver Map API, CoreLocation

Naver Map API 가이드
https://navermaps.github.io/ios-map-sdk/reference/NMapsGeometry.html

https://navermaps.github.io/ios-map-sdk/guide-ko/

</br>

* ## 개발자
: 박진서, 심영민

</br>

* ## 개발 기간
: 4/19 ~ 개발중

</br>

* ## 앱스토어
![image](https://user-images.githubusercontent.com/20080283/82233091-6cd98800-996a-11ea-90a6-6c6493a85d4d.png)

</br>

#### URL

https://apps.apple.com/kr/app/%EA%B2%BD%EA%B8%B0%EC%A7%80%EC%97%AD%ED%99%94%ED%8F%90-%EC%82%AC%EC%9A%A9%EC%B2%98/id1511379295

</br>

![image](https://user-images.githubusercontent.com/20080283/82176555-104a7e80-9912-11ea-92c6-54a20b195e17.png)
: 5/18 기준 다운로드 현황

</br>

* ## 기능 (ver 1.5)

</br>

#### 경기도 전 지역의 지역화폐 가맹점 데이터 다운로드

<img width="410" alt="스크린샷 2020-05-19 오전 12 53 13" src="https://user-images.githubusercontent.com/20080283/82234176-081f2d00-996c-11ea-900c-31e9d67470c1.png"> <img width="404" alt="스크린샷 2020-05-19 오전 12 59 05" src="https://user-images.githubusercontent.com/20080283/82234185-0c4b4a80-996c-11ea-9c3f-c7388445bd10.png">

</br>

#### 지도에서 마커로 가맹점의 위치 표시
: 공공 데이터 포털에서 제공하는 각 가맹점의 위/경도 데이터는 같은 건물에 위치한 경우 무조건 위/경도가 동일하게 나오므로
</br>
아래와 같이 여러 가게들을 묶어서 표시함. 해당 가게 클릭 시 전화로 연결됨.

<img width="400" alt="스크린샷 2020-05-19 오전 12 54 49" src="https://user-images.githubusercontent.com/20080283/82234189-0e150e00-996c-11ea-8c03-c328fd69271b.png"> <img width="404" alt="스크린샷 2020-05-19 오전 12 55 20" src="https://user-images.githubusercontent.com/20080283/82234193-0f463b00-996c-11ea-9c53-f53569f18ae4.png">

</br>

#### 가맹점 검색 기능
: 해당하는 가맹점을 선택하면 지도로 이동하여 위치 표시

<img width="400" alt="스크린샷 2020-05-19 오전 12 55 44" src="https://user-images.githubusercontent.com/20080283/82234200-10776800-996c-11ea-9882-85b867bf559a.png"> <img width="403" alt="스크린샷 2020-05-19 오전 12 57 51" src="https://user-images.githubusercontent.com/20080283/82234203-11a89500-996c-11ea-9feb-192d25ef9bab.png">
<img width="400" alt="스크린샷 2020-05-19 오전 12 58 42" src="https://user-images.githubusercontent.com/20080283/82234206-12412b80-996c-11ea-930b-e179881eaff7.png">

</br>

#### 제작자, 버전 표시
<img width="400" alt="스크린샷 2020-05-19 오전 12 53 30" src="https://user-images.githubusercontent.com/20080283/82234187-0d7c7780-996c-11ea-9735-a64e912ba647.png">





</br>

## 제작 LOG

#### 4/26 
가게 검색 기능 추가
</br></br>
<img width="300" alt="스크린샷 2020-04-26 오후 7 44 41" src="https://user-images.githubusercontent.com/20080283/80305225-7dc52c80-87f6-11ea-9a93-c2bf78892448.png"> <img width="300" alt="스크린샷 2020-04-26 오후 7 45 00" src="https://user-images.githubusercontent.com/20080283/80305227-7f8ef000-87f6-11ea-9314-a292a74cfb13.png">

#### 5/3
1. 지도에서 마커 클릭 시 위도 경도 겹쳐있는 여러 가게 정보들 한꺼번에 표시 및 가게 클릭 시 전화하는 기능 추가

<img width="300" alt="스크린샷 2020-05-03 오후 5 58 55" src="https://user-images.githubusercontent.com/20080283/80910075-08aea580-8d68-11ea-8f0c-f8b96386a021.png"> <img width="300" alt="스크린샷 2020-05-03 오후 5 58 19" src="https://user-images.githubusercontent.com/20080283/80910074-077d7880-8d68-11ea-88ab-260c224d03ad.png">

2. 현위치 기준 검색한 가게들의 거리 표시

<img width="300" alt="스크린샷 2020-05-03 오후 5 57 30" src="https://user-images.githubusercontent.com/20080283/80910067-01879780-8d68-11ea-806b-1c6da3fe1f2f.png">

3. 검색한 가게 선택 시 해당 위도 경도로 이동

<img width="300" alt="스크린샷 2020-05-03 오후 5 57 58" src="https://user-images.githubusercontent.com/20080283/80910072-064c4b80-8d68-11ea-91b9-9ab7c7d30914.png">

4. 특정 지역 가맹점 데이터 다운로드 기능

<img width="300" alt="스크린샷 2020-05-03 오후 5 57 40" src="https://user-images.githubusercontent.com/20080283/80910070-05b3b500-8d68-11ea-8ee0-f9637ee2ab68.png">

#### 5/3 ~ 5/18
1. 앱스토어 등록: https://apps.apple.com/kr/app/%EA%B2%BD%EA%B8%B0%EC%A7%80%EC%97%AD%ED%99%94%ED%8F%90-%EC%82%AC%EC%9A%A9%EC%B2%98/id1511379295

5/18 기준 다운로드 현황

![image](https://user-images.githubusercontent.com/20080283/82176555-104a7e80-9912-11ea-92c6-54a20b195e17.png)


#### 5/18~19

UI 대거 변경

<img width="400" alt="스크린샷 2020-05-19 오전 12 54 49" src="https://user-images.githubusercontent.com/20080283/82234189-0e150e00-996c-11ea-8c03-c328fd69271b.png"><img width="403" alt="스크린샷 2020-05-19 오전 12 57 51" src="https://user-images.githubusercontent.com/20080283/82234203-11a89500-996c-11ea-9feb-192d25ef9bab.png">



