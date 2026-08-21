FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["ActiveTogether.Subscriber/ActiveTogether.Subscriber.csproj", "ActiveTogether.Subscriber/"]
COPY ["ActiveTogether.Model/ActiveTogether.Model.csproj", "ActiveTogether.Model/"]
RUN dotnet restore "ActiveTogether.Subscriber/ActiveTogether.Subscriber.csproj"
COPY . .
WORKDIR /src/ActiveTogether.Subscriber
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/runtime:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ActiveTogether.Subscriber.dll"]