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
    '*.html',
    '*.xql',
    'templates/**/*',
    'transforms/**/*',
    'resources/**/*',
    '!resources/css/*',
    'modules/**/*',
    'components/demo/**'
];

gulp.task('deploy:other', function () {
    return gulp.src(otherPaths, {base: './'})
        .pipe(exClient.newer(targetConfiguration))
        .pipe(exClient.dest(targetConfiguration))
})

gulp.task('deploy', ['deploy:other'])

gulp.task('watch', ['deploy'], function () {
    gulp.watch(otherPaths, ['deploy:other'])
})

gulp.task('default', ['watch'])
