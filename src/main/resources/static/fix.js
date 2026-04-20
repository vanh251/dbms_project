const fs = require('fs');
const path = require('path');

const dir = 'c:/Users/Admin/dbms_project/src/main/resources/static';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.html'));

files.forEach(file => {
    const filePath = path.join(dir, file);
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Replace <div id="navAuth"></div> placed INSIDE .nav-links
    // With <div id="navAuth"></div> placed AFTER .nav-links
    content = content.replace(/<div id="navAuth"><\/div>\s*<\/div>\s*<\/nav>/g, '</div>\n    <div id="navAuth"></div>\n</nav>');
    
    fs.writeFileSync(filePath, content);
    console.log('Fixed', file);
});
