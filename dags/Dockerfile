FROM python:3.11.4

RUN apt update

RUN apt upgrade -y

RUN apt install -y zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN chsh -s /bin/zsh
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="ys"/g' /root/.zshrc

RUN apt install -y netcat-openbsd net-tools iputils-ping

# Set environment varibles
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

COPY ./src/pyproject.toml ./src/poetry.lock /app
RUN pip install --upgrade pip
RUN pip install poetry
