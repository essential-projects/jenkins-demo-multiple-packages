const fs = require('fs');
const metaFile = JSON.parse(fs.readFileSync(__dirname + '/../.meta', 'utf8'));
const projectsInMetaFile = metaFile.projects;

const listOfProjects = [];
for (const project in projectsInMetaFile) {
  listOfProjects.push(project);
}

console.log(JSON.stringify(listOfProjects));
