# meradio 📻

57개 한국 라디오 방송국을 **메뉴 바**에서 바로 듣는 네이티브 macOS 앱.
SwiftUI `MenuBarExtra`로 제작 — 독 아이콘도 창도 없이 메뉴 바에 상주합니다.

방송국 목록과 스트림 URL은 [radio-korea.com](https://www.radio-korea.com)에서 추출합니다.

랜딩 페이지: **https://rescenedev.github.io/meradio/**

## 설치

### Homebrew (권장)

```bash
brew tap rescenedev/tap
brew install --cask rescenedev/tap/meradio
```

### 직접 다운로드

[최신 릴리스에서 `meradio.dmg` 다운로드](https://github.com/rescenedev/meradio/releases/latest/download/meradio.dmg)
→ 열어서 `meradio.app`을 `Applications`로 드래그.

> Developer ID 서명 + Apple 공증(notarized) 완료 — Gatekeeper 경고 없이 실행됩니다.

## 기능

- 메뉴 바 상주 (`LSUIElement`) — 독/앱 스위처에 표시되지 않음
- 57개 한국 라디오 방송국 (HLS / AAC / MP3 라이브 스트림)
- **탭**: 즐겨찾기 / 최근 재생 / 전체
- 방송국 검색, 즐겨찾기(별표), 실시간 곡 정보(ICY/ID3) 표시
- 볼륨 조절, 스트림 실패 시 대체 URL 자동 전환
- **시작 모드**: 끄기 / 랜덤 / 마지막 방송 / 고정 방송국
- **예약 켜기·끄기**: 특정 시간(요일별)에 자동 재생/정지
- Slate 다크 디자인

## 빌드 & 실행

```bash
# 개발용 (ad-hoc 서명)
./scripts/build-app.sh release && open meradio.app

# 빠른 반복
swift build && swift run
```

요구사항: macOS 14+, Swift 6 / Xcode 16+.

## 릴리스 (서명 · 공증 · 패키징)

```bash
./scripts/package-dmg.sh    # Developer ID 서명 + hardened runtime + DMG 생성
./scripts/notarize.sh       # Apple 공증 + staple (notarytool 키체인 프로필 사용)
```

`notarize.sh`는 기본적으로 `pomodoro-notary` 키체인 프로필을 사용합니다
(공증 자격증명은 앱 단위가 아니라 Apple 계정 단위). 다른 프로필을 쓰려면
`NOTARY_PROFILE=내프로필 ./scripts/notarize.sh`.

## 방송국 목록 갱신

```bash
node tools/extract_stations.mjs
```

`tools/station_list.json`(경로 → 이름)을 기반으로 각 방송국 페이지의 암호화된
스트림 디스크립터를 복호화해 `Sources/meradio/Resources/stations.json`을 재생성합니다.

### 스트림 URL 복호화

radio-korea.com(myTuner/regional-radios 플랫폼)은 스트림 URL을
`{cipher, iv, type}`로 암호화해 내려보냅니다:

1. `cipher`: base64url → base64
2. 키: `last-update` 타임스탬프 문자열의 char code를 16진수로 32바이트까지 순환 → AES-256 키
3. `iv`: 16진수 디코드
4. **AES-256-CFB** 복호화 후 **PKCS7 패딩 제거**
5. `chunklist.m3u8`(시간 의존)은 상위 `playlist.m3u8`를 우선 사용, 원본은 대체 URL로 보관

## 구조

```
Sources/meradio/
  App.swift               진입점 + AppState(스토어/스케줄러)
  Models/                 Station, AppSettings(StartupMode, Schedule)
  Stores/                 StationStore, Favorites, SettingsStore
  Player/                 RadioPlayer(AVPlayer), Scheduler
  Views/                  Theme(slate), 메뉴 바 UI, 설정, 스케줄 편집
  Resources/stations.json 추출된 방송국 데이터
scripts/                  build-app / package-dmg / notarize / Info.plist
docs/                     랜딩 페이지 + 개인정보처리방침 (GitHub Pages)
tools/                    스트림 추출 스크립트
```

## 라이선스 / 출처

방송국 정보 출처: radio-korea.com. 개인 용도 프로젝트입니다.
