
install:
	docker build -t wmluke/jenkins-slave .

clean:
	docker rm -f jenkins-slave

run:
	docker run -i -t --rm wmluke/jenkins-slave /bin/bash
