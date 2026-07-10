# self-hosted-aca

Azure Container Apps + KEDA 기반 GitHub Actions self-hosted runner를 통해
**Azure App Service**에 배포하는 것을 테스트하기 위한 간단한 Node.js(Express) 웹앱입니다.

## 로컬 실행

```bash
npm install
npm start
# http://localhost:8080 접속
```

- `GET /` : 배포 확인용 JSON 응답 (호스트명, 배포 시각 등 포함)
- `GET /health` : 헬스체크 엔드포인트 (200 OK)

## Azure App Service 배포 요구사항

이 리포지토리의 `.github/workflows/deploy.yml`은 **self-hosted runner**
(`runs-on: [self-hosted, container-app]`)에서 실행되도록 구성되어 있습니다.
Runner는 Azure Container Apps Jobs + KEDA로 구성하며, 자세한 인프라 구성은
별도 문서(`github-actions-runners-on-aca-keda.md`)를 참고하세요.

워크플로우가 정상 동작하려면 리포지토리에 아래 값을 설정해야 합니다.

| 종류 | 이름 | 설명 |
|---|---|---|
| Variable | `AZURE_WEBAPP_NAME` | 배포 대상 Azure App Service 이름 |
| Secret | `AZURE_WEBAPP_PUBLISH_PROFILE` | App Service의 Publish Profile(XML) 전체 내용 |

Publish Profile은 Azure Portal → App Service → **Overview → Get publish profile**
에서 다운로드하거나 아래 CLI로 확인할 수 있습니다.

```bash
az webapp deployment list-publishing-profiles \
  --name <app-service-name> --resource-group <resource-group> --xml
```

> Runner가 Private VNet(Internal Container Apps Environment) 안에 있는 경우,
> App Service의 SCM/Kudu 엔드포인트에 접근 가능한 네트워크 경로(Private Endpoint,
> VNet 통합 등)가 별도로 필요합니다 — 이 부분은 후속 작업에서 다룹니다.

## 워크플로우 트리거

- `main` 브랜치에 push 시 자동 실행
- Actions 탭에서 **Run workflow**로 수동 실행 가능 (`workflow_dispatch`)
