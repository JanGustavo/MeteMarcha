#!/bin/bash

# Cores para o terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem Cor

echo -e "${BLUE}=== Mete Marcha Fit: Release Automator 🚀 ===${NC}\n"

# 1. Verifica se a versão foi passada
if [ -z "$1" ]; then
    echo -e "${RED}Erro: Você precisa especificar a versão da release (ex: 1.5.2).${NC}"
    echo -e "Uso: ./release.sh [versao]"
    exit 1
fi

NEW_VERSION_ARG=$1

# Valida o formato da versão (ex: 1.5.2)
if [[ ! $NEW_VERSION_ARG =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Erro: A versão deve estar no formato X.Y.Z (ex: 1.5.2).${NC}"
    exit 1
fi

# 2. Verifica se o git está limpo
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}Aviso: Você possui alterações não salvas no repositório.${NC}"
    read -p "Deseja commitar essas alterações automaticamente com a mensagem 'bump: prepara release $NEW_VERSION_ARG'? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add -A
        git commit -m "bump: prepara release $NEW_VERSION_ARG"
    else
        echo -e "${RED}Por favor, salve ou dê stash nas suas alterações antes de rodar a release.${NC}"
        exit 1
    fi
fi

# 3. Lê e incrementa o build number do pubspec.yaml
VERSION_LINE=$(grep "^version:" pubspec.yaml)
if [ -z "$VERSION_LINE" ]; then
    echo -e "${RED}Erro: Não foi possível encontrar a linha de versão no pubspec.yaml.${NC}"
    exit 1
fi

CURRENT_VERSION_FULL=$(echo "$VERSION_LINE" | cut -d' ' -f2)
CURRENT_BUILD=$(echo "$CURRENT_VERSION_FULL" | cut -d'+' -f2)

# Se o build number atual for vazio ou não for número, define como 1
if [[ ! $CURRENT_BUILD =~ ^[0-9]+$ ]]; then
    NEW_BUILD=1
else
    NEW_BUILD=$((CURRENT_BUILD + 1))
fi

NEW_VERSION_FULL="${NEW_VERSION_ARG}+${NEW_BUILD}"

echo -e "Versão atual:  ${YELLOW}${CURRENT_VERSION_FULL}${NC}"
echo -e "Nova versão:   ${GREEN}${NEW_VERSION_FULL}${NC}\n"

# 4. Atualiza o pubspec.yaml
echo -e "Atualizando pubspec.yaml..."
sed -i "s/^version: .*/version: $NEW_VERSION_FULL/" pubspec.yaml

# 5. Executa os testes
echo -e "\n${BLUE}Rodando testes do Flutter para validação...${NC}"
if ! flutter test; then
    echo -e "${RED}Erro: Alguns testes falharam!${NC}"
    read -p "Deseja abortar a release? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "Restaurando pubspec.yaml..."
        git checkout pubspec.yaml
        exit 1
    fi
else
    echo -e "${GREEN}Todos os testes passaram com sucesso!${NC}"
fi

# 6. Commita a alteração da versão
echo -e "\nCommitando a alteração da versão..."
git add pubspec.yaml
git commit -m "chore: bump version to $NEW_VERSION_FULL"

# 7. Cria a tag local
TAG_NAME="v${NEW_VERSION_ARG}"
echo -e "Criando tag ${GREEN}${TAG_NAME}${NC}..."
git tag "$TAG_NAME"

# 8. Push de commits e tags
read -p "Deseja realizar o push das alterações e da tag para o repositório remoto? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "Enviando commits..."
    git push origin HEAD
    echo -e "Enviando tag..."
    git push origin "$TAG_NAME"
    
    # 9. Cria a Release no GitHub (se o gh estiver disponível)
    if command -v gh &> /dev/null; then
        read -p "Deseja criar a Release no GitHub com notas automáticas? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "Criando Release no GitHub..."
            gh release create "$TAG_NAME" --title "$TAG_NAME" --generate-notes
            echo -e "${GREEN}Release no GitHub criada com sucesso!${NC}"
        fi
    else
        echo -e "${YELLOW}Nota: CLI 'gh' não encontrada. Pulei a criação automática de release no GitHub.${NC}"
    fi
else
    echo -e "${YELLOW}Push ignorado. Lembre-se de enviar a tag manualmente depois: git push origin $TAG_NAME${NC}"
fi

echo -e "\n${GREEN}Processo de release para $NEW_VERSION_FULL concluído com sucesso! 🏁${NC}"
