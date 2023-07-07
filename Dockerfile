FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
# Install necessary dependencies
RUN apt-get update \
    && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN groupadd -r myuser && useradd -r -g myuser -G audio,video myuser \
    && mkdir -p /home/myuser/Downloads \
    && chown -R myuser:myuser /home/myuser

# Set up working directory and user permissions
WORKDIR /app
RUN chown -R myuser:myuser /app

# Switch to the non-root user
USER myuser

# Expose ports
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["PdfConverter.csproj", "."]
RUN dotnet restore "./PdfConverter.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "PdfConverter.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "PdfConverter.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "PdfConverter.dll"]