'use strict';

const gulp = require('gulp'),
    exist = require('@existdb/gulp-exist'),
    del = require('del')

const exClient = exist.createClient({
    host: 'localhost',
    port: '8080',
    path: '/exist/xmlrpc',
    basic_auth: {user: 'wap', pass: ''}
})

const targetConfiguration = { target: '/db/apps/wap/' }

gulp.task('clean', function () {
    return del(['build/**/*']);
});

// files in project root //

var otherPaths = [
    '*.xql',
    'icon.png',
    'configuration.xml',
    'modules/**/*',
];

gulp.task('deploy:other', function () {
    return gulp.src(otherPaths, {base: './'})
        .pipe(exClient.newer(targetConfiguration))
        .pipe(exClient.dest(targetConfiguration))
})

gulp.task('deploy', gulp.series('deploy:other'))

gulp.task('watch', gulp.series('deploy', function () {
    gulp.watch(otherPaths, gulp.series('deploy:other'))
}))

gulp.task('default', gulp.series('watch'))
