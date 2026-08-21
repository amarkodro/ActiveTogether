FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["ActiveTogether.WebAPI/ActiveTogether.WebAPI.csproj", "ActiveTogether.WebAPI/"]
COPY ["ActiveTogether.Services/ActiveTogether.Services.csproj", "ActiveTogether.Services/"]
COPY ["ActiveTogether.Model/ActiveTogether.Model.csproj", "ActiveTogether.Model/"]
RUN dotnet restore "ActiveTogether.WebAPI/ActiveTogether.WebAPI.csproj"
COPY . .
WORKDIR /src/ActiveTogether.WebAPI
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "ActiveTogether.WebAPI.dll"]